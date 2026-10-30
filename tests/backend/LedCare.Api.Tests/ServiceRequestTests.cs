using System.Net;
using System.Net.Http.Json;
using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Modules.ServiceRequests;
using LedCare.Api.Tests.Infrastructure;
using Microsoft.AspNetCore.Mvc;

namespace LedCare.Api.Tests;

[Collection(ApiCollection.Name)]
public sealed class ServiceRequestTests(LedCareApiFactory factory)
{
    [Fact]
    public async Task Customer_creates_request_with_reference_history_and_cancel_option()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        var created = await ServiceRequestTestData.CreateAsync(customer, "Panel titremesi var");

        Assert.Equal(ServiceRequestStatus.New, created.Status);
        Assert.Matches(@"^LC-\d{6}$", created.ReferenceCode);
        Assert.Equal(DevelopmentDataSeeder.CustomerAId, created.CustomerId);
        Assert.Equal([ServiceRequestStatus.Cancelled], created.AllowedTransitions);
        var history = Assert.Single(created.History);
        Assert.Null(history.FromStatus);

        var fetched = await (await customer.GetAsync($"/api/service-requests/{created.Id}")).ReadAsync<ServiceRequestDetailDto>();
        Assert.Equal(created.Id, fetched!.Id);
    }

    [Fact]
    public async Task Invalid_payload_returns_validation_problem()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        var response = await customer.PostAsJsonAsync("/api/service-requests", new { title = "x", description = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var problem = await response.ReadAsync<ValidationProblemDetails>();
        Assert.Equal("Girilen bilgiler geçersiz", problem!.Title);
        Assert.Contains("title", problem.Errors.Keys);
        Assert.Equal("Açıklama zorunludur.", Assert.Single(problem.Errors["description"]));
    }

    [Fact]
    public async Task Staff_cannot_create_requests_in_phase_0()
    {
        using var admin = await factory.CreateClientForAsync(DevelopmentDataSeeder.AdminEmail);
        var response = await admin.PostAsJsonAsync("/api/service-requests", new { title = "Yönetici talebi", description = "Yönetici tarafından açılmaya çalışılan talep." });
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Customers_are_isolated_from_each_other()
    {
        using var customerA = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var customerB = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerBEmail);
        var requestOfA = await ServiceRequestTestData.CreateAsync(customerA);

        // Direct ID access, status change and list must all hide A's request from B.
        Assert.Equal(HttpStatusCode.NotFound, (await customerB.GetAsync($"/api/service-requests/{requestOfA.Id}")).StatusCode);
        var cancel = await customerB.PostAsJsonAsync($"/api/service-requests/{requestOfA.Id}/status",
            new { status = "Cancelled", version = requestOfA.Version }, Json.Options);
        Assert.Equal(HttpStatusCode.NotFound, cancel.StatusCode);

        var listOfB = await (await customerB.GetAsync("/api/service-requests?pageSize=100")).ReadAsync<PagedResult<ServiceRequestSummaryDto>>();
        Assert.DoesNotContain(listOfB!.Items, r => r.Id == requestOfA.Id);
        Assert.All(listOfB.Items, r => Assert.Equal(DevelopmentDataSeeder.CustomerBId, r.CustomerId));
    }

    [Fact]
    public async Task Organizations_are_isolated_from_each_other()
    {
        using var customerA = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var otherManager = await factory.CreateClientForAsync(DevelopmentDataSeeder.OtherOrgManagerEmail);
        var requestOfA = await ServiceRequestTestData.CreateAsync(customerA);

        Assert.Equal(HttpStatusCode.NotFound, (await otherManager.GetAsync($"/api/service-requests/{requestOfA.Id}")).StatusCode);
        var list = await (await otherManager.GetAsync("/api/service-requests?pageSize=100")).ReadAsync<PagedResult<ServiceRequestSummaryDto>>();
        Assert.DoesNotContain(list!.Items, r => r.Id == requestOfA.Id);

        // Claiming membership of an organization the user does not belong to is refused.
        using var spoof = new HttpRequestMessage(HttpMethod.Get, "/api/service-requests");
        spoof.Headers.Add("X-Organization-Id", DevelopmentDataSeeder.CentralOrganizationId.ToString());
        Assert.Equal(HttpStatusCode.Forbidden, (await otherManager.SendAsync(spoof)).StatusCode);
    }

    [Fact]
    public async Task Technicians_without_assignments_see_no_requests()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var technician = await factory.CreateClientForAsync(DevelopmentDataSeeder.RemoteTechEmail);
        var request = await ServiceRequestTestData.CreateAsync(customer);

        var list = await (await technician.GetAsync("/api/service-requests")).ReadAsync<PagedResult<ServiceRequestSummaryDto>>();
        Assert.Equal(0, list!.TotalCount);
        Assert.Equal(HttpStatusCode.NotFound, (await technician.GetAsync($"/api/service-requests/{request.Id}")).StatusCode);
    }

    [Fact]
    public async Task Staff_changes_status_and_customer_sees_it_with_history()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var dispatcher = await factory.CreateClientForAsync(DevelopmentDataSeeder.DispatcherEmail);
        var created = await ServiceRequestTestData.CreateAsync(customer);

        var staffView = await (await dispatcher.GetAsync($"/api/service-requests/{created.Id}")).ReadAsync<ServiceRequestDetailDto>();
        Assert.Contains(ServiceRequestStatus.InReview, staffView!.AllowedTransitions);

        var response = await dispatcher.PostAsJsonAsync($"/api/service-requests/{created.Id}/status",
            new { status = "InReview", version = staffView.Version, note = "Uzaktan inceleme planlandı" }, Json.Options);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var updated = await response.ReadAsync<ServiceRequestDetailDto>();
        Assert.Equal(ServiceRequestStatus.InReview, updated!.Status);
        Assert.NotEqual(created.Version, updated.Version);

        var customerView = await (await customer.GetAsync($"/api/service-requests/{created.Id}")).ReadAsync<ServiceRequestDetailDto>();
        Assert.Equal(ServiceRequestStatus.InReview, customerView!.Status);
        Assert.Equal(2, customerView.History.Count);
        Assert.Equal("Uzaktan inceleme planlandı", customerView.History[^1].Note);
    }

    [Fact]
    public async Task Customer_may_only_cancel_own_request()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        var created = await ServiceRequestTestData.CreateAsync(customer);

        var forbidden = await customer.PostAsJsonAsync($"/api/service-requests/{created.Id}/status",
            new { status = "Resolved", version = created.Version }, Json.Options);
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);

        var cancelled = await customer.PostAsJsonAsync($"/api/service-requests/{created.Id}/status",
            new { status = "Cancelled", version = created.Version }, Json.Options);
        Assert.Equal(HttpStatusCode.OK, cancelled.StatusCode);
        Assert.Empty((await cancelled.ReadAsync<ServiceRequestDetailDto>())!.AllowedTransitions);
    }

    [Fact]
    public async Task Workflow_rejects_transitions_that_skip_steps()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var admin = await factory.CreateClientForAsync(DevelopmentDataSeeder.AdminEmail);
        var created = await ServiceRequestTestData.CreateAsync(customer);

        var response = await admin.PostAsJsonAsync($"/api/service-requests/{created.Id}/status",
            new { status = "Closed", version = created.Version }, Json.Options);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Stale_version_returns_conflict()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var admin = await factory.CreateClientForAsync(DevelopmentDataSeeder.AdminEmail);
        var created = await ServiceRequestTestData.CreateAsync(customer);

        var first = await admin.PostAsJsonAsync($"/api/service-requests/{created.Id}/status",
            new { status = "InReview", version = created.Version }, Json.Options);
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);

        var second = await admin.PostAsJsonAsync($"/api/service-requests/{created.Id}/status",
            new { status = "InProgress", version = created.Version }, Json.Options);
        Assert.Equal(HttpStatusCode.Conflict, second.StatusCode);
    }

    [Fact]
    public async Task Concurrent_status_changes_with_same_version_allow_only_one_winner()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        using var admin = await factory.CreateClientForAsync(DevelopmentDataSeeder.AdminEmail);
        using var dispatcher = await factory.CreateClientForAsync(DevelopmentDataSeeder.DispatcherEmail);
        var created = await ServiceRequestTestData.CreateAsync(customer);

        var responses = await Task.WhenAll(
            admin.PostAsJsonAsync($"/api/service-requests/{created.Id}/status", new { status = "InReview", version = created.Version }, Json.Options),
            dispatcher.PostAsJsonAsync($"/api/service-requests/{created.Id}/status", new { status = "InProgress", version = created.Version }, Json.Options));

        Assert.Single(responses, r => r.StatusCode == HttpStatusCode.OK);
        Assert.Single(responses, r => r.StatusCode == HttpStatusCode.Conflict);
    }

    [Fact]
    public async Task List_filters_by_status_and_paginates()
    {
        using var customer = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerBEmail);
        using var admin = await factory.CreateClientForAsync(DevelopmentDataSeeder.AdminEmail);
        await ServiceRequestTestData.CreateAsync(customer);
        await ServiceRequestTestData.CreateAsync(customer);

        var page = await (await admin.GetAsync("/api/service-requests?status=New&page=1&pageSize=1")).ReadAsync<PagedResult<ServiceRequestSummaryDto>>();
        Assert.Single(page!.Items);
        Assert.True(page.TotalCount >= 2);
        Assert.All(page.Items, r => Assert.Equal(ServiceRequestStatus.New, r.Status));
    }
}

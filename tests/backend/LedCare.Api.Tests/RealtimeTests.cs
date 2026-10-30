using System.Net;
using System.Threading.Channels;
using LedCare.Api.Infrastructure.Persistence;
using LedCare.Api.Infrastructure.Realtime;
using LedCare.Api.Tests.Infrastructure;
using Microsoft.AspNetCore.Http.Connections;
using Microsoft.AspNetCore.SignalR.Client;
using Microsoft.Extensions.DependencyInjection;

namespace LedCare.Api.Tests;

[Collection(ApiCollection.Name)]
public sealed class RealtimeTests(LedCareApiFactory factory)
{
    [Fact]
    public async Task Hub_requires_authentication_and_accepts_query_string_token()
    {
        using var client = factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.PostAsync($"{NotificationsHub.Path}/negotiate?negotiateVersion=1", null)).StatusCode);

        var tokens = await factory.LoginAsync(DevelopmentDataSeeder.CustomerAEmail);
        var negotiate = await client.PostAsync($"{NotificationsHub.Path}/negotiate?negotiateVersion=1&access_token={Uri.EscapeDataString(tokens.AccessToken)}", null);
        Assert.Equal(HttpStatusCode.OK, negotiate.StatusCode);
    }

    [Fact]
    public async Task Change_events_reach_staff_and_owning_customer_only()
    {
        await using var staff = await ConnectAsync(DevelopmentDataSeeder.DispatcherEmail);
        await using var owner = await ConnectAsync(DevelopmentDataSeeder.CustomerAEmail);
        await using var otherCustomer = await ConnectAsync(DevelopmentDataSeeder.CustomerBEmail);
        await using var otherOrganization = await ConnectAsync(DevelopmentDataSeeder.OtherOrgManagerEmail);

        using var customerClient = await factory.CreateClientForAsync(DevelopmentDataSeeder.CustomerAEmail);
        var created = await ServiceRequestTestData.CreateAsync(customerClient);

        var staffEvent = await staff.WaitForAsync(created.Id);
        Assert.Equal("created", staffEvent.Change);
        var ownerEvent = await owner.WaitForAsync(created.Id);
        Assert.Equal(created.Version, ownerEvent.Version);

        // Other recipients must not receive anything about this request.
        Assert.False(await otherCustomer.ReceivedAsync(created.Id, TimeSpan.FromSeconds(1)));
        Assert.False(await otherOrganization.ReceivedAsync(created.Id, TimeSpan.FromMilliseconds(200)));
    }

    private async Task<HubListener> ConnectAsync(string email)
    {
        var tokens = await factory.LoginAsync(email);
        var connection = new HubConnectionBuilder()
            .WithUrl(new Uri(factory.Server.BaseAddress, NotificationsHub.Path), o =>
            {
                o.Transports = HttpTransportType.LongPolling;
                o.HttpMessageHandlerFactory = _ => factory.Server.CreateHandler();
                o.AccessTokenProvider = () => Task.FromResult<string?>(tokens.AccessToken);
            })
            .AddJsonProtocol(o => o.PayloadSerializerOptions = Json.Options)
            .Build();

        var listener = new HubListener(connection);
        await connection.StartAsync();
        return listener;
    }

    private sealed class HubListener : IAsyncDisposable
    {
        private readonly HubConnection _connection;
        private readonly Channel<ServiceRequestChangedEvent> _events = Channel.CreateUnbounded<ServiceRequestChangedEvent>();

        public HubListener(HubConnection connection)
        {
            _connection = connection;
            _connection.On<ServiceRequestChangedEvent>(NotificationsHub.ServiceRequestChangedEvent, e => _events.Writer.TryWrite(e));
        }

        public async Task<ServiceRequestChangedEvent> WaitForAsync(Guid serviceRequestId)
        {
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
            while (true)
            {
                var e = await _events.Reader.ReadAsync(cts.Token);
                if (e.ServiceRequestId == serviceRequestId)
                {
                    return e;
                }
            }
        }

        public async Task<bool> ReceivedAsync(Guid serviceRequestId, TimeSpan wait)
        {
            try
            {
                await Task.Delay(wait);
                while (_events.Reader.TryRead(out var e))
                {
                    if (e.ServiceRequestId == serviceRequestId)
                    {
                        return true;
                    }
                }

                return false;
            }
            catch (OperationCanceledException)
            {
                return false;
            }
        }

        public ValueTask DisposeAsync() => _connection.DisposeAsync();
    }
}

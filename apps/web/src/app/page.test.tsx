import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { t } from "@/lib/i18n";
import HomePage, { metadata } from "./page";

describe("HomePage", () => {
  it("renders the marketing content in Turkish with a single h1", () => {
    render(<HomePage />);
    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(t.home.heroTitle);
    for (const service of t.home.services) {
      expect(screen.getByRole("heading", { level: 3, name: service.title })).toBeInTheDocument();
    }
    expect(
      screen.getByRole("heading", { level: 2, name: t.home.brandIndependentTitle }),
    ).toBeInTheDocument();
  });

  it("links to login and to service request creation", () => {
    render(<HomePage />);
    expect(screen.getByRole("link", { name: t.nav.login })).toHaveAttribute("href", "/giris");
    const ctas = screen.getAllByRole("link", { name: new RegExp(t.home.heroPrimaryCta) });
    expect(ctas[0]).toHaveAttribute("href", "/giris?next=%2Fmusteri");
  });

  it("exports SEO metadata", () => {
    expect(metadata.description).toBe(t.home.metaDescription);
    expect(metadata.alternates?.canonical).toBe("/");
  });
});

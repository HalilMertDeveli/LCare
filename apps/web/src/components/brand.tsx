import { cn } from "@/lib/utils";

/** LEDCare OS logo mark: a small LED-matrix glyph. */
export function BrandMark({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden
      className={cn("size-7 shrink-0", className)}
      fill="none"
    >
      <rect width="24" height="24" rx="5" fill="var(--color-primary)" />
      {[5, 10, 15].map((y) =>
        [5, 10, 15].map((x) => (
          <rect
            key={`${x}-${y}`}
            x={x}
            y={y}
            width="4"
            height="4"
            rx="1"
            fill="white"
            opacity={x === 10 && y === 10 ? 1 : 0.75}
          />
        )),
      )}
    </svg>
  );
}

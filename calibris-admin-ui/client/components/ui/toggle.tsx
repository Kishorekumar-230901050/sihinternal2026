import * as React from "react";
import * as TogglePrimitive from "@radix-ui/react-toggle";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

export const toggleVariants = cva(
  "inline-flex items-center justify-center font-semibold transition-colors rounded-md " +
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
  {
    variants: {
      variant: {
        default:
          "bg-transparent text-[#6AA6FF] hover:bg-[#6AA6FF]/15 hover:text-[#6AA6FF]",

        outline:
          "border border-input bg-transparent hover:bg-[#6AA6FF]/15 hover:text-[#6AA6FF]",

        // NEW: segment for your LIST / MAP toggle
        segment:
          // Base
          "bg-transparent text-[#6AA6FF] px-4 py-2 rounded-md transition-colors " +
          // Hover when OFF
          "hover:bg-[#6AA6FF]/15 hover:text-[#6AA6FF] " +
          // Selected state
          "data-[state=on]:bg-[#6AA6FF] data-[state=on]:text-white " +
          // Hover when selected
          "data-[state=on]:hover:bg-[#6AA6FF]/90",
      },

      size: {
        default: "h-9 px-3 text-sm",
        sm: "h-8 px-2 text-xs",
        lg: "h-10 px-4 text-base",
      },
    },

    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

const Toggle = React.forwardRef<
  React.ElementRef<typeof TogglePrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof TogglePrimitive.Root> &
    VariantProps<typeof toggleVariants>
>(({ className, variant, size, ...props }, ref) => (
  <TogglePrimitive.Root
    ref={ref}
    className={cn(toggleVariants({ variant, size, className }))}
    {...props}
  />
));

Toggle.displayName = TogglePrimitive.Root.displayName;

export { Toggle };

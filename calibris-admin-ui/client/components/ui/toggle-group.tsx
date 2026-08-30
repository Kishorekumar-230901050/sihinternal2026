import * as React from "react";
import * as ToggleGroupPrimitive from "@radix-ui/react-toggle-group";
import { cn } from "@/lib/utils";

export const ToggleGroup = React.forwardRef<
  React.ElementRef<typeof ToggleGroupPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof ToggleGroupPrimitive.Root>
>(({ className, children, ...props }, ref) => (
  <ToggleGroupPrimitive.Root
    ref={ref}
    className={cn("flex border-b border-[#1f2a3a] gap-6 pb-1 justify-center", className)}
    {...props}
  >
    {children}
  </ToggleGroupPrimitive.Root>
));

ToggleGroup.displayName = ToggleGroupPrimitive.Root.displayName;

export const ToggleGroupItem = React.forwardRef<
  React.ElementRef<typeof ToggleGroupPrimitive.Item>,
  React.ComponentPropsWithoutRef<typeof ToggleGroupPrimitive.Item>
>(({ className, children, ...props }, ref) => (
  <ToggleGroupPrimitive.Item
    ref={ref}
    className={cn(
      "relative px-2 py-1 text-sm font-semibold text-[#9bb7e0] transition-colors",
      // Hover (text brightening)
      "hover:text-[#cfe2ff]",
      // Active
      "data-[state=on]:text-[#6AA6FF]",
      // Underline (matches navbar exactly)
      "data-[state=on]:after:absolute data-[state=on]:after:left-0 data-[state=on]:after:right-0 data-[state=on]:after:-bottom-1 data-[state=on]:after:h-[2px] data-[state=on]:after:bg-[#6AA6FF]",
      className
    )}
    {...props}
  >
    {children}
  </ToggleGroupPrimitive.Item>
));

ToggleGroupItem.displayName = ToggleGroupPrimitive.Item.displayName;

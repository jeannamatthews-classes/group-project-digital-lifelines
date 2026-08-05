import { useEffect, useState } from "react";
import { X, Download } from "lucide-react";
import { Button } from "./buttons";
import { cn } from "../../lib/utils";

const ANIMATION_MS = 300;

export function PopUp() {
  const [mounted, setMounted] = useState(true);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const frame = requestAnimationFrame(() => setVisible(true));
    return () => cancelAnimationFrame(frame);
  }, []);

  function handleClose() {
    setVisible(false);
    window.setTimeout(() => setMounted(false), ANIMATION_MS);
  }

  if (!mounted) return null;

  return (
        <div
          className={cn(
            "fixed bottom-6 right-6 z-50 max-w-sm rounded-xl border border-border bg-background/95 p-4 pt-6 pr-8 shadow-xl backdrop-blur",
            "transition-all duration-300 ease-out",
            visible
              ? "translate-x-0 opacity-100"
              : "pointer-events-none translate-x-full opacity-0",
          )}
        >
            <button
                onClick={handleClose}
                className="absolute right-1 top-1 rounded-md p-1 text-muted-foreground hover:bg-muted transition-colors hover:text-foreground"
                aria-label="Close"
                >
                <X className="h-4 w-4" />
            </button>
            <div className="flex items-center gap-4">
                <div>
                    <p className="font-medium">Get the App here!</p>
                </div>
                <Button asChild>
                    <a href="https://sacbloctwbvcnkadihty.supabase.co/storage/v1/object/public/Downloadables/app-release.apk" download>
                        <Download className="h-4 w-4" />
                        Download
                    </a>
                </Button>
            </div>
        </div>
    )
}
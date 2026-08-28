import { useEffect, useRef, useState } from "react";
import { X, Download, Smartphone, Apple } from "lucide-react";
import { Button } from "./buttons";
import { cn } from "../../lib/utils";

const ANIMATION_MS = 300;

export function PopUp() {
  const [mounted, setMounted] = useState(true);
  const [visible, setVisible] = useState(false);
  const [showPlatformChooser, setShowPlatformChooser] = useState(false);
  const closeTimer = useRef<number | undefined>(undefined);

  useEffect(() => {
    const frame = requestAnimationFrame(() => setVisible(true));
    const handleOpen = () => {
      if (closeTimer.current) window.clearTimeout(closeTimer.current);
      setMounted(true);
      requestAnimationFrame(() => setVisible(true));
      setShowPlatformChooser(true);
    };

    window.addEventListener("open-app-popup", handleOpen);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("open-app-popup", handleOpen);
    };
  }, []);

  function handleClose() {
    setVisible(false);
    closeTimer.current = window.setTimeout(() => setMounted(false), ANIMATION_MS);
  }

  function handleDownloadClick() {
    setShowPlatformChooser(true);
  }

  if (!mounted) return null;

  return (
    <>
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
          className="absolute right-1 top-1 rounded-md p-1 text-muted-foreground cursor-pointer transition-colors hover:bg-muted hover:text-foreground"
          aria-label="Close"
        >
          <X className="h-4 w-4" />
        </button>
        <div className="flex items-center gap-4">
          <div>
            <p className="font-medium">Get the App here!</p>
          </div>
          <Button onClick={handleDownloadClick}>
            <Download className="h-4 w-4" />
            Download
          </Button>
        </div>
      </div>

      {showPlatformChooser && (
        <div
          className="fixed inset-0 z-60 flex items-center justify-center bg-black/50 p-4 backdrop-blur-sm"
          role="dialog"
          aria-modal="true"
          aria-labelledby="download-options-title"
        >
          <div className="relative w-full max-w-2xl rounded-xl border border-border bg-background p-6 shadow-2xl sm:p-8">
            <button
              onClick={() => setShowPlatformChooser(false)}
              className="absolute right-3 top-3 rounded-md p-1 text-muted-foreground cursor-pointer transition-colors hover:bg-muted hover:text-foreground"
              aria-label="Close download options"
            >
              <X className="h-5 w-5" />
            </button>
            <div className="pr-8">
              <h2 id="download-options-title" className="text-xl font-semibold">
                Choose your device
              </h2>
              <p className="mt-1 text-sm text-muted-foreground">
                Select an option to get the Digital Lifelines app.
              </p>
            </div>

            <div className="mt-6 grid gap-4 md:grid-cols-2">
              <div className="rounded-lg border border-border p-5">
                <div className="flex items-center gap-3">
                  <Smartphone className="h-5 w-5" aria-hidden="true" />
                  <h3 className="font-semibold">Android</h3>
                </div>
                <p className="mt-3 text-sm text-muted-foreground">
                  Download and install the Android app directly.
                </p>
                <Button asChild className="mt-5 w-full">
                  <a
                    href="https://sacbloctwbvcnkadihty.supabase.co/storage/v1/object/public/Downloadables/DigitalLifelines.apk"
                    download
                  >
                    <Download className="h-4 w-4" />
                    Download for Android
                  </a>
                </Button>
              </div>

              <div className="rounded-lg border border-border p-5">
                <div className="flex items-center gap-3">
                  <Apple className="h-5 w-5" aria-hidden="true" />
                  <h3 className="font-semibold">iOS</h3>
                </div>
                <ol className="mt-3 list-decimal space-y-2 pl-5 text-sm text-muted-foreground">
                  <li>Install the free <a
                      href="https://apps.apple.com/us/app/testflight/id899247664"
                      target="_blank"
                      rel="noreferrer"
                      className="font-medium text-foreground underline underline-offset-2"
                    >TestFlight app</a> from the App Store.</li>
                  <li>
                    Tap this link on your iPhone:{" "}
                    <a
                      href="https://testflight.apple.com/join/ME6uMzQq"
                      target="_blank"
                      rel="noreferrer"
                      className="font-medium text-foreground underline underline-offset-2"
                    >
                      Download Digital Lifelines
                    </a>
                  </li>
                  <li>Tap &quot;Accept,&quot; then &quot;Install.&quot;</li>
                </ol>
                <p className="mt-4 text-xs text-muted-foreground">
                  Note: requires iOS 16 or later
                </p>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
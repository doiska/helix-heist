import { useEffect } from "preact/hooks";

export function useUIEvent(event: string, callback: (event: Event) => void) {
  useEffect(() => {
    const abortController = new AbortController();

    window.addEventListener(
      "message",
      (clientEvent) => {
        if (clientEvent.data.event === event) {
          callback(clientEvent.data.data);
        }
      },
      {
        signal: abortController.signal,
      },
    );

    return () => {
      abortController.abort();
    };
  }, [event, callback]);
}

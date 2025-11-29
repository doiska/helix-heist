import { useEffect } from "preact/hooks";
import { parseCallbackResponse } from "../../lib/event-response";

export function useUIEvent(
  event: string,
  callback: <T = unknown>(payload: T) => void,
) {
  useEffect(() => {
    const abortController = new AbortController();

    window.addEventListener(
      "message",
      (clientEvent) => {
        const response = parseCallbackResponse(clientEvent);

        if (response.name === event) {
          callback(response.data);
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

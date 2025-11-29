import { useState, useEffect } from "preact/hooks";
import { queryCache } from "./query-cache";
import { parseCallbackResponse } from "../../lib/event-response";

export function useClientQuery<Output = unknown>({
  queryKey,
  event,
  payload,
  enabled = true,
}: {
  queryKey: string[];
  event: string;
  payload?: unknown;
  enabled?: boolean;
}) {
  const [status, setStatus] = useState<
    "idle" | "loading" | "success" | "error"
  >("idle");

  const [error, setError] = useState<string | undefined>(undefined);
  const [_, setCacheVersion] = useState(0);

  const fetchData = () => {
    if (!enabled) return;

    const abortController = new AbortController();

    const timeoutId = setTimeout(() => {
      if (!abortController.signal.aborted) {
        abortController.abort("Timed out");
        setStatus("error");
        setError("Request timed out");
      }
    }, 5000);

    const handleMessage = (messageEvent: MessageEvent) => {
      const response = parseCallbackResponse(messageEvent);

      if (!response.data) {
        console.error(`Missing callback response for ${event}`);
        return;
      }

      if (response.name !== `${event}_callback`) {
        return;
      }

      //TODO: validate if the event we received is the same as were expecting

      if (abortController.signal.aborted) {
        console.error(
          `Tried to respond to ${event} after it was aborted due to timeout`,
        );
        return;
      }

      //todo: safe parse it
      const result = response.data;

      if (result.status === "success") {
        queryCache.setQueryData(queryKey, result.data);
        setError(undefined);
        setStatus("success");
      } else if (result.status === "error") {
        setError(result.message);
        setStatus("error");
      } else {
        console.error(`Received invalid payload ${JSON.stringify(result)}`);
      }

      clearTimeout(timeoutId);
      abortController.abort();
    };

    window.addEventListener("message", handleMessage, {
      signal: abortController.signal,
    });

    setStatus("loading");
    window.hEvent(event, payload);

    return () => {
      abortController.abort();
      clearTimeout(timeoutId);
    };
  };

  useEffect(() => {
    if (!enabled) {
      setStatus("idle");
      return;
    }

    return fetchData();
  }, [event, JSON.stringify(payload), JSON.stringify(queryKey), enabled]);

  useEffect(() => {
    const unsubscribe = queryCache.subscribe(queryKey, () => {
      setCacheVersion((v) => v + 1);
    });

    return unsubscribe;
  }, [JSON.stringify(queryKey)]);

  const refetch = () => {
    if (enabled) {
      fetchData();
    }
  };

  const data = queryCache.getQueryData<Output>(queryKey);

  return {
    data,
    error,
    status,
    refetch,
  };
}

import { useState, useEffect } from "preact/hooks";

type CallbackResponse<Data = never> =
  | {
      status: "success";
      data: Data;
    }
  | {
      status: "error";
      message: string;
    };

// tried to make a low-cost version of useQuery from @tanstack/react-query so we can fetch and cache the data using queryKey
// TODO: add refetchInterval or refresh on mount

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
  const [data, setData] = useState<Output | undefined>(undefined);

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
      if (abortController.signal.aborted) {
        console.error(
          `Tried to respond to ${event} after it was aborted due to timeout`,
        );
        return;
      }

      const result = messageEvent.data as CallbackResponse<Output>;

      if (result.status === "success") {
        setData(result.data);
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

  const refetch = () => {
    if (enabled) {
      fetchData();
    }
  };

  return {
    data,
    error,
    status,
    refetch,
  };
}

import { useState } from "preact/hooks";
import { processCallbackResponse } from "../../lib/event-response";

type CallbackResponse<Data = never> =
  | {
      status: "success";
      data: Data;
    }
  | {
      status: "error";
      message: string;
    };

declare global {
  namespace globalThis {
    function hEvent(event: string, payload?: unknown): void;
  }
}

export function useUIMutation<Output = unknown>() {
  const [status, setStatus] = useState<
    "idle" | "loading" | "success" | "error"
  >("idle");

  const [error, setError] = useState<string | undefined>(undefined);
  const [data, setData] = useState<Output | undefined>(undefined);

  async function mutate<Input = unknown>(event: string, payload?: Input) {
    const abortController = new AbortController();

    const timeoutId = setTimeout(() => {
      if (!abortController.signal.aborted) {
        abortController.abort("Timed out");
        setStatus("error");
        setError("Request timed out");
      }
    }, 5000);

    const handleMessage = (messageEvent: MessageEvent) => {
      const response = processCallbackResponse(messageEvent);

      console.log(JSON.stringify(response));

      if (!response.data) {
        console.error(`No callback response by ${event}`);
        return;
      }

      if (response.name !== `${event}_callback`) {
        return;
      }

      console.log(`Received ${event} callback.`);

      if (abortController.signal.aborted) {
        console.error(
          `Tried to respond to ${event} after it was aborted due to timeout`,
        );
        return;
      }

      //todo: safe parse it
      const result = response.data;

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
  }

  return {
    mutate,
    status,
    data,
    error,
  };
}

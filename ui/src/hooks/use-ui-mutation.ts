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

export function useUIMutation() {
  async function mutate<Output = unknown, Input = unknown>(
    event: string,
    payload?: Input,
  ) {
    const abortController = new AbortController();

    const handleCallback = (result: CallbackResponse<Output>) => {
      setTimeout(() => {
        if (!abortController.signal.aborted) {
          abortController.abort("Timed out");
        }
      }, 5000);

      if (result.status === "success") {
        return result.data;
      } else {
        throw new Error(result.message);
      }
    };

    window.addEventListener(
      "message",
      (event) => {
        const result = event.data as CallbackResponse<Output>;
        handleCallback(result);
      },
      {
        // using a abort controller with auto cleanup (via timeout) to avoid mem leak
        signal: abortController.signal,
      },
    );

    window.hEvent(event, payload);
  }

  return {
    mutate,
  };
}

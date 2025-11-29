type CallbackResponse<Data = never> =
  | {
      status: "success";
      data: Data;
    }
  | {
      status: "error";
      message: string;
    };

export function useUIMutation() {
  async function mutate<Output = unknown, Input = unknown>(
    event: string,
    payload?: Input,
  ) {
    const handleCallback = (result: CallbackResponse<Output>) => {
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
        // im trying this new static to prevent memory leaks and auto cleanup the event
        signal: AbortSignal.timeout(5000),
      },
    );

    window.hEvent(event, payload);
  }

  return {
    mutate,
  };
}

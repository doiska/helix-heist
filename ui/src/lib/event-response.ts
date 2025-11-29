type CallbackResponse<Data = never> =
  | {
      status: "success";
      data: Data;
    }
  | {
      status: "error";
      message: string;
    };

export function parseCallbackResponse<Output = never>(
  messageEvent: MessageEvent,
) {
  const response = messageEvent.data as { name: string; args?: string };

  try {
    if (!response.args) {
      // imo it should always have a status
      throw new Error("No status found in callback response");
    }

    return {
      name: response.name,
      data:
        // Hack to get the first arg and make the fn work
        typeof response.args === "string"
          ? (JSON.parse(response.args)?.[0] as CallbackResponse<Output>)
          : (response.args?.[0] as CallbackResponse<Output>),
    };
  } catch (err) {
    console.error(err);

    return {
      name: response.name,
      data: null,
    };
  }
}

import { type MutableRefObject, useEffect, useRef } from "react";
import {
  parseCallbackResponse,
  type CallbackResponse,
} from "../lib/event-response";

interface HelixPayload<T = unknown> {
  name: string;
  args: T[];
}

type CallbackSignature<Output> = (data: CallbackResponse<Output>) => void;

export const useUIEvent = <T extends unknown>(
  action: string,
  handler: CallbackSignature<T>,
) => {
  const savedHandler: MutableRefObject<CallbackSignature<T>> = useRef(() => {});

  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const abortController = new AbortController();

    window.addEventListener(
      "message",
      (event: MessageEvent<HelixPayload<T>>) => {
        const { name, data } = parseCallbackResponse(event);

        if (savedHandler.current) {
          if (name === action) {
            savedHandler.current(data as CallbackResponse<T>);
          }
        }
      },
      {
        signal: abortController.signal,
      },
    );

    return () => abortController.abort();
  }, [action]);
};

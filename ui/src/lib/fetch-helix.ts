export async function fetchHelix<T = unknown>(
  eventName: string,
  data?: unknown,
): Promise<T> {
  return new Promise((resolve) => {
    if ((window as any).hEvent) {
      (window as any).hEvent(eventName, data, (result: T) => {
        resolve(result);
      });
    }
  });
}

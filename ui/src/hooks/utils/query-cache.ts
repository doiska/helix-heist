type QueryKey = readonly unknown[];
type Updater<T> = (old: T | undefined) => T;

class QueryCache {
  private cache = new Map<string, unknown>();
  private listeners = new Map<string, Set<() => void>>();

  private getKey(queryKey: QueryKey): string {
    return JSON.stringify(queryKey);
  }

  setQueryData<T>(queryKey: QueryKey, updater: T | Updater<T>) {
    const key = this.getKey(queryKey);
    const oldData = this.cache.get(key) as T | undefined;

    const newData =
      typeof updater === "function"
        ? (updater as Updater<T>)(oldData)
        : updater;

    this.cache.set(key, newData);
    this.notify(key);
  }

  getQueryData<T>(queryKey: QueryKey): T | undefined {
    const key = this.getKey(queryKey);
    return this.cache.get(key) as T | undefined;
  }

  subscribe(queryKey: QueryKey, listener: () => void) {
    const key = this.getKey(queryKey);
    if (!this.listeners.has(key)) {
      this.listeners.set(key, new Set());
    }
    this.listeners.get(key)!.add(listener);

    return () => {
      const listeners = this.listeners.get(key);
      if (listeners) {
        listeners.delete(listener);
        if (listeners.size === 0) {
          this.listeners.delete(key);
        }
      }
    };
  }

  private notify(key: string) {
    const listeners = this.listeners.get(key);
    if (listeners) {
      listeners.forEach((listener) => listener());
    }
  }
}

export const queryCache = new QueryCache();

export function useQueryCache() {
  return {
    setQueryData: <T,>(queryKey: QueryKey, updater: T | Updater<T>) => {
      queryCache.setQueryData(queryKey, updater);
    },
    getQueryData: <T,>(queryKey: QueryKey) => {
      return queryCache.getQueryData<T>(queryKey);
    },
  };
}

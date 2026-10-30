"use client";

import { useCallback, useEffect, useRef, useState } from "react";

import { ApiError, redirectToLogin } from "@/lib/api/client";

export interface Resource<T> {
  data: T | undefined;
  error: unknown;
  /** True only while there is no result yet for the current deps (first load). */
  loading: boolean;
  /** Re-fetches; keeps showing the previous data meanwhile. Resolves when done. */
  reload: () => Promise<void>;
}

interface State<T> {
  key: string;
  data?: T;
  error?: unknown;
  done: boolean;
}

/**
 * Loads data from the API with abort-on-supersede semantics. A 401 sends the user to the
 * login page; every other error is exposed for the component to render.
 * `deps` must be JSON-serialisable; when they change the previous result is discarded.
 */
export function useResource<T>(
  loader: (signal: AbortSignal) => Promise<T>,
  deps: readonly unknown[],
): Resource<T> {
  const key = JSON.stringify(deps);
  const [state, setState] = useState<State<T>>({ key, done: false });
  const controller = useRef<AbortController | null>(null);
  const loaderRef = useRef(loader);
  const keyRef = useRef(key);
  useEffect(() => {
    loaderRef.current = loader;
    keyRef.current = key;
  });

  const run = useCallback(async () => {
    controller.current?.abort();
    const ac = new AbortController();
    controller.current = ac;
    const runKey = keyRef.current;
    try {
      const result = await loaderRef.current(ac.signal);
      if (ac.signal.aborted) return;
      setState({ key: runKey, data: result, error: undefined, done: true });
    } catch (err) {
      if (ac.signal.aborted) return;
      if (err instanceof ApiError && err.kind === "unauthorized") {
        redirectToLogin();
        return;
      }
      setState((s) =>
        s.key === runKey
          ? { ...s, error: err, done: true }
          : { key: runKey, error: err, done: true },
      );
    }
  }, []);

  useEffect(() => {
    void run();
    return () => controller.current?.abort();
  }, [key, run]);

  // When deps change, the stored result belongs to the old key: treat it as not loaded.
  const current: State<T> = state.key === key ? state : { key, done: false };
  return { data: current.data, error: current.error, loading: !current.done, reload: run };
}

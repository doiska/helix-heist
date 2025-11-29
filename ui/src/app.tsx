import { useState } from "preact/hooks";
import { HeistLobby } from "./components/heist-lobby";
import { useUIEvent } from "./hooks/utils/use-client-event";

export function App() {
  const [isLoaded, setLoaded] = useState(false);

  useUIEvent("Loaded", () => {
    setLoaded(true);
  });

  return isLoaded ? <HeistLobby /> : null;
}

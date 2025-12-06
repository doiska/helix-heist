import { useState } from "preact/hooks";
import { useUIEvent } from "./hooks/use-ui-event";
import { MinigameLockpick } from "./components/minigames/minigame-lockpick";

type MinigameBase = {
  id: string;
  type: "door" | "vault";
  minigameType: "lockpick" | "pattern";
  timeLimit: number;
  attemptsRemaining: number;
  maxAttempts: number;
};

export function App() {
  const [isLoaded, setLoaded] = useState(false);
  const [currentMinigame, setCurrentMinigame] = useState<MinigameBase | null>(
    null,
  );

  useUIEvent<MinigameBase | null>("StartMinigame", (result) => {
    if (result.status === "success") {
      setCurrentMinigame(result.data);
    }
  });

  useUIEvent("HideMinigame", () => setCurrentMinigame(null));
  useUIEvent("Loaded", () => setLoaded(true));

  if (!isLoaded) {
    return null;
  }

  if (!currentMinigame) {
    return null;
  }

  if (currentMinigame.minigameType === "lockpick") {
    return (
      <MinigameLockpick
        minigameId={currentMinigame.id}
        maxAttempts={currentMinigame.maxAttempts}
        initialAttemptsRemaining={currentMinigame.attemptsRemaining}
      />
    );
  }

  return null;
}

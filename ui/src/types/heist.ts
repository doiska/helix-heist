export interface HeistLobby {
  id: string;
  state: string;
  participants: number;
  leader: string;
  canJoin: boolean;
}

export const HeistStates = {
  IDLE: "IDLE",
  PREPARED: "PREPARED",
  ENTRY: "ENTRY",
  VAULT_LOCKED: "VAULT_LOCKED",
  VAULT_OPEN: "VAULT_OPEN",
  LOOTING: "LOOTING",
  ESCAPE: "ESCAPE",
  COMPLETE: "COMPLETE",
  FAILED: "FAILED",
} as const;

export type HeistState = (typeof HeistStates)[keyof typeof HeistStates];

export interface UserHeistState {
  inHeist: boolean;
  state: HeistState;
  heistId: string | null;
}

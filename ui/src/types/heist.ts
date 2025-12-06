export interface HeistLobby {
  id: string;
  state: string;
  participants: number;
  leader: string;
  canJoin: boolean;
}

enum HeistStates {
  IDLE = "IDLE",
  PREPARED = "PREPARED",
  ENTRY = "ENTRY",
  VAULT_LOCKED = "VAULT_LOCKED",
  VAULT_OPEN = "VAULT_OPEN",
  LOOTING = "LOOTING",
  ESCAPE = "ESCAPE",
  COMPLETE = "COMPLETE",
  FAILED = "FAILED",
}

export interface UserHeistState {
  inHeist: boolean;
  state: HeistStates;
  heistId: string | null;
}


export interface ITblStudent {
  id?: number;
  name: string;
  lastname: string;
  email: string;
  password: string;
  tel: string;

  role?: {
    id: number;
    name?: string;
  };
}

export class TblStudent implements ITblStudent {
  constructor(
    public name: string,
    public lastname: string,
    public email: string,
    public password: string,
    public tel: string,

    public role?: {
      id: number;
      name?: string;
    },

    public id?: number
  ) {}
}

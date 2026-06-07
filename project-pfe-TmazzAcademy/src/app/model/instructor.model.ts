import { Role } from "./role.model";

export interface ITblInstuctor {
  id?: number;
  name?: string;
  lastname?: string;
  email?: string;
  password?: string;
  tel?: string;
  speciality?: string;
  role?: Role;
}

export class TblInstuctor implements ITblInstuctor {
  constructor(
    public id?: number,
    public name?: string,
    public lastname?: string,
    public email?: string,
    public password?: string,
    public tel?: string,
    public speciality?: string,
    public role?: Role
  ) {}
}
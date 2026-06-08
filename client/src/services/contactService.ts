import axios from "axios";

const API = "http://localhost:5000/api";

export const getContactSettings = async () => {
  try {
    const res = await axios.get(`${API}/settings/contact`);
    return res.data;
  } catch {
    return null;
  }
};
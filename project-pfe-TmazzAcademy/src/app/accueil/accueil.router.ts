import { Routes } from "@angular/router";
import { Layout } from "./layout/layout";
import { Accueil } from "./layout/container/accueil/accueil";
import { Login } from "./layout/container/login/login";
import { Inscript } from "./layout/container/inscript/inscript";
import { About } from "./layout/container/about/about";

export const accueilRoute: Routes = [ 
    {
        path:'',component:Layout,
        children:[
          {path:'',component:Accueil},
          {path:'About',component:About},
          {path:'Login',component:Login},
          {path:'Inscript',component:Inscript}
          // {path:'**',component:HomeComponent}
        ]
      } 
];
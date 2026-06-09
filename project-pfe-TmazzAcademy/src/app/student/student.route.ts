import { Routes } from "@angular/router";
import { Layout } from "./layout/layout";
import { Profile } from "./layout/container/profile/profile";
import { Cours } from "./layout/container/cours/cours";
import { Sertif } from "./layout/container/sertif/sertif";
import { CourseDetails } from "./layout/container/course-details/course-details";
import { Favorites } from "./layout/container/favorites/favorites";
import { Accueil } from "./layout/container/accueil/accueil";
import { Payment } from "./layout/container/payment/payment";
import { Chat } from "./layout/container/chat/chat";

export const studentRoute: Routes = [ 
    {
        path:'',component:Layout,
        children:[
          {path:'',component:Accueil},
          {path:'Cours',component:Cours},
          {path:'Chat',component:Chat},
          { path: 'Courses/:id', component: CourseDetails },
          { path: 'Favorites', component: Favorites },
          {path:'Sertif',component:Sertif},
          {path:'Payment',component:Payment},
          {path:'Profile',component:Profile}
          // {path:'**',component:HomeComponent}
        ]
      } 
];
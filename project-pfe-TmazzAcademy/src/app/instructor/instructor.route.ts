import { Routes } from "@angular/router";
import { Layout } from "./layout/layout";
import { Profile } from "./layout/container/profile/profile";
import { Cours } from "./layout/container/cours/cours";
import { Sertif } from "./layout/container/sertif/sertif";
import { Students } from "./layout/container/students/students";
import { CourseQuestions } from "./layout/container/course-questions/course-questions";
import { Dashboard } from "./layout/container/dashboard/dashboard";
import { Accueil } from "./layout/container/accueil/accueil";
import { Chat } from "./layout/container/chat/chat";

export const instructorRoute: Routes = [ 
    {
        path:'',component:Layout,
        children:[
          {path:'',component:Accueil},
          {path:'Cours',component:Cours},
          {path:'Chat',component:Chat},
          {path:'Sertif',component:Sertif},
          { path: 'Questions/:id', component: CourseQuestions },
          { path:'Dashboard', component: Dashboard },
          { path:'Profile', component: Profile },
          {path:'Students',component:Students}
          // {path:'**',component:HomeComponent}
        ]
      } 
];
import { Routes } from "@angular/router";
import { Layout } from "./layout/layout";
import { Profile } from "./layout/container/profile/profile";
import { Instructors } from "./layout/container/instructors/instructors";
import { Students } from "./layout/container/students/students";
import { OurInstructors } from "./layout/container/our-instructors/our-instructors";
import { Accept } from "./layout/container/accept/accept";
import { OurStudents } from "./layout/container/our-students/our-students";
import { Members } from "./layout/container/members/members";
import { Dashboard } from "./layout/container/dashboard/dashboard";
import { Courses } from "./layout/container/courses/courses";
import { Payments } from "./layout/container/payments/payments";
import { Accueil } from "./layout/container/accueil/accueil";
import { Chat } from "./layout/container/chat/chat";

export const adminRoute: Routes = [ 
    {
        path:'',component:Layout,
        children:[
          {path:'',component:Accueil},// /admin
          {path:'Instructors',component:Instructors},// /admin/instructors/
          {path:'Chat',component:Chat},// /admin/Chat
          {path:'Profile',component:Profile},// /admin/Profile
          {path:'Students',component:Students}, // /admin/students 
          {path:'OurInstructors',component:OurInstructors}, // /admin/OurInstructors 
          {path:'OurStudents', component: OurStudents },// /admin/OurStudentss 
          {path:'Accept', component: Accept },// /admin/Accept  
          { path:'Courses', component: Courses },// /admin/Courses 
          { path:'Dashboard', component: Dashboard },// /admin/Dashboard  
          { path:'Payments', component: Payments }, // /admin/Payments
          {path:'Members', component: Members }// /admin/Members  
          // {path:'**',component:HomeComponent}
        ]
      } 
];

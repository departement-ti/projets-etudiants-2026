import { Routes } from '@angular/router';
import { accueilRoute } from './accueil/accueil.router';
import { adminRoute } from './admin/admin.route';
import { instructorRoute } from './instructor/instructor.route';
import { studentRoute } from './student/student.route';
import { RoleGuard } from './guards/role-guard';

export const routes: Routes = [
    { path: '', children: accueilRoute },
{path: 'admin',canActivate: [RoleGuard],data: { role: 'ADMIN' },children: adminRoute},
{path: 'instructor',canActivate: [RoleGuard],data: { role: 'INSTRUCTOR' },children: instructorRoute},
{path: 'student',canActivate: [RoleGuard],data: { role: 'STUDENT' },children: studentRoute},
{ path: '**', redirectTo: '' }
];
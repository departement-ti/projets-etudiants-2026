import { Injectable } from '@angular/core';
import { CanActivate, Router, ActivatedRouteSnapshot } from '@angular/router';

@Injectable({
  providedIn: 'root'
})
export class RoleGuard implements CanActivate {

  constructor(private router: Router) {}

  canActivate(route: ActivatedRouteSnapshot): boolean {

    const token =
      typeof window !== 'undefined'
        ? localStorage.getItem('token')
        : null;

    const role =
      typeof window !== 'undefined'
        ? localStorage.getItem('role')
        : null;

    // ما فماش login
    if (!token) {
      this.router.navigate(['/login']);
      return false;
    }

    // role المطلوب من route
    const expectedRole = route.data['role'];

    // مسموح
    if (role === expectedRole) {
      return true;
    }

    // موش مسموح
    this.router.navigate(['/login']);
    return false;
  }
}
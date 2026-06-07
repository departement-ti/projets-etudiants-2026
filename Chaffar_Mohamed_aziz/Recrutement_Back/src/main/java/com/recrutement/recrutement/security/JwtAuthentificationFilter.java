package com.recrutement.recrutement.security;

import com.recrutement.recrutement.entities.Role;
import com.recrutement.recrutement.entities.User;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.crypto.SecretKey;
import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthentificationFilter extends OncePerRequestFilter {
    private final JwtUtils jwtUtils;
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) throws ServletException {
        String path = request.getServletPath();
        String method = request.getMethod();
        return "OPTIONS".equalsIgnoreCase(method) || path.startsWith("/api/auth/");
    }
    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {

            final String authHeader = request.getHeader("Authorization");
            final String jwt;
            final String userEmail;

            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                filterChain.doFilter(request, response);
                return;
            }

            jwt = authHeader.substring(7);
            userEmail = jwtUtils.extractUsername(jwt);

            if (userEmail != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                User user = buildUserFromToken(jwt, userEmail);

                if (user != null && jwtUtils.isTokenValid(jwt, user.getEmail())) {
                    List<SimpleGrantedAuthority> authorities = List.of(
                            new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
                    );

                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            user,
                            null,
                            authorities
                    );
                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }

            filterChain.doFilter(request, response);
        }

    private User buildUserFromToken(String jwt, String userEmail) {
        try {
            String roleValue = jwtUtils.extractClaim(jwt, claims -> claims.get("role", String.class));
            Object userIdValue = jwtUtils.extractClaim(jwt, claims -> claims.get("userId"));
            String nom = jwtUtils.extractClaim(jwt, claims -> claims.get("nom", String.class));

            if (roleValue == null || roleValue.isBlank()) {
                return null;
            }

            User user = new User();
            user.setEmail(userEmail);
            user.setNom(nom == null ? userEmail : nom);
            user.setRole(Role.valueOf(roleValue));
            user.setStatutCompte(true);

            if (userIdValue instanceof Number number) {
                user.setId(number.longValue());
            }

            return user;
        } catch (Exception ex) {
            return null;
        }
    }
}


package com.tmazzacademy.tmazzacademy.config;

import org.springframework.http.HttpMethod;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import com.tmazzacademy.tmazzacademy.security.JwtFilter;
import com.tmazzacademy.tmazzacademy.security.MyUserDetailsService;

@Configuration
public class SecurityConfig {

    @Autowired
    private JwtFilter jwtFilter;

    @Autowired
    private MyUserDetailsService userDetailsService;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> {})
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth

                // LOGIN
                .requestMatchers("/auth/login").permitAll()

                // REGISTER only ADMIN
                .requestMatchers("/auth/register").hasRole("ADMIN")

                // PUBLIC INSCRIPTION
                .requestMatchers("/api/inscription/**").permitAll()

                // ADMIN ACCEPT INSCRIPTIONS
                .requestMatchers("/api/admin/inscriptions/**").hasRole("ADMIN")
                
                // FILES
                .requestMatchers("/uploads/**").permitAll()
                
                // COMMENTS INSIDE COURSES
                .requestMatchers(HttpMethod.GET, "/api/cours/comments/**").permitAll()

                // COURS
                .requestMatchers("/api/cours/**").permitAll()
                
                // FAVORITE 
                .requestMatchers("/api/favorites/**").permitAll()
                
                // COMMENTS
                .requestMatchers("/api/comments/**").permitAll()
                
                // QUESTIONS
                .requestMatchers("/api/questions/**").permitAll()
                
                //TESTS
                .requestMatchers("/api/tests/**").permitAll()
                
                //CERTIFICATES
                .requestMatchers("/api/certificates/**").permitAll()
                
                //DASHBOARD
                .requestMatchers("/api/dashboard/**").permitAll()
                
                //CHATBOT
                .requestMatchers("/api/chatbot/**").permitAll()
                

                // USERS
                .requestMatchers("/users/admin/**").hasRole("ADMIN")
                .requestMatchers("/users/instructors", "/users/instructors/**")
                    .hasAnyRole("ADMIN", "INSTRUCTOR")
                .requestMatchers("/users/students", "/users/students/**")
                    .hasAnyRole("ADMIN", "STUDENT")

                .anyRequest().authenticated()
            )
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .authenticationProvider(authenticationProvider());

        http.addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        config.setAllowedOrigins(List.of("http://localhost:4200"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);

        return source;
    }
}
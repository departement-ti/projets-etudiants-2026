package com.recrutement.recrutement.service;

import com.recrutement.recrutement.dto.*;
import com.recrutement.recrutement.entities.User;
import java.util.List;

public interface AuthService {
    RegisterResponse registerCandidate(CandidateRegisterRequest request);

    RegisterResponse registerRecruiter(RecruiterRegisterRequest request);

    RegisterResponse registerAdmin(AdminRegisterRequest request);

    LoginResponse login(LoginRequest request);

    String activateAccount(String token);

    RegisterResponse approveRecruiter(Long recruiterId);

    MessageResponse rejectRecruiter(Long recruiterId);

    List<RegisterResponse> getRecruiterAccounts();

    void deleteRecruiterAccount(Long recruiterId);

    MessageResponse suspendRecruiterAccount(Long recruiterId);

    List<UserSummaryResponse> getUsers(String query);

    UserProfileResponse getUserById(Long userId);

    MessageResponse deleteUser(Long userId);

    MessageResponse suspendUser(Long userId);

    MessageResponse activateUser(Long userId);

    MessageResponse forgotPassword(ForgotPasswordRequest request);

    MessageResponse resetPassword(ResetPasswordRequest request);

    MessageResponse changePassword(User currentUser, ChangePasswordRequest request);
}

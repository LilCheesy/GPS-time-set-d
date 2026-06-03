package com.carebrigde.backjavaspring.entity.user;

import com.carebrigde.backjavaspring.entity.base.BaseEntity;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "users")
@Data @NoArgsConstructor @AllArgsConstructor
public class User extends BaseEntity {
    @Column(unique = true, nullable = false, length = 100)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(length = 50)
    private String fullName;

    @Column(length = 20)
    private String phoneNumber;

    @Column(length = 20)
    private String role = "USER"; // USER, CAREGIVER, ADMIN

    @Column(length = 500)
    private String avatarUrl;

    @Column(nullable = false)
    private boolean emailVerified = false;

    @Column
    private LocalDateTime lastLoginAt;
}

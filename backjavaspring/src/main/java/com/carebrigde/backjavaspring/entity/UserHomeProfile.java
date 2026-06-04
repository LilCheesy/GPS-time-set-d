package com.carebrigde.backjavaspring.entity;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Point;

@Entity
@Table(name = "user_home_profiles", indexes = {
    @Index(name = "idx_home_user", columnList = "user_id"),
    @Index(name = "idx_home_location", columnList = "home_location", using = "GIST")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserHomeProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;

    @Column(nullable = false)
    private String addressLabel;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false, columnDefinition = "geometry(Point, 4326)")
    private Point homeLocation;

    @Column
    private String floorNumber;

    @Column
    private String roomNumber;

    @Column(nullable = false)
    private Boolean isPrimaryHome = true;
}

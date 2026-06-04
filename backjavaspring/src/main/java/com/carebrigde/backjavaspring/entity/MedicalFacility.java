package com.carebrigde.backjavaspring.entity;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Point;

@Entity
@Table(name = "medical_facilities", indexes = {
    @Index(name = "idx_facility_location", columnList = "location")
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MedicalFacility {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String address;

    @Column(nullable = false)
    private String phone;

    private String facilityType;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false, columnDefinition = "geometry(Point, 4326)")
    private Point location;

    @Builder.Default
    @Column(nullable = false)
    private Boolean isActive = true;
}

package com.carebrigde.backjavaspring.controller;

import com.carebrigde.backjavaspring.dto.auth.SosRequest;
import com.carebrigde.backjavaspring.dto.auth.SosResponse;
import com.carebrigde.backjavaspring.service.SosService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/sos")
@RequiredArgsConstructor
public class SosController {

    private final SosService sosService;

    @PostMapping
    public ResponseEntity<SosResponse> sendSos(@Valid @RequestBody SosRequest request) {
        SosResponse response = sosService.processSos(request);
        return ResponseEntity.ok(response);
    }
}

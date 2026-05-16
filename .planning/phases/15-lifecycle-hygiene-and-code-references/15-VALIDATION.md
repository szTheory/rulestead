# Phase 15: Nyquist Validation Strategy

## Overview
This document defines the validation strategy for Phase 15: Lifecycle Hygiene and Code References, ensuring that stale flag tracking and code reference ingestion are correctly implemented and integrated.

## Test Strategy

1. **Unit Testing**
   - Telemetry ETS Cache & Oban Worker: Verify cache updates on evaluation, snapshot retrieval, and asynchronous Oban processing into persistent storage.
   - AST Code Reference Scanner: Ensure `Rulestead.evaluate/2` calls are parsed accurately to identify line numbers and files while ignoring irrelevant ASTs.
   - Code Refs Ingress Plug & Webhook: Verify API token authentication, payload structure validation, and accurate storage.
   - LiveView Cleanup Confirmations: Verify UI strictly matches expected confirmation states, displaying references properly.

2. **Integration Testing**
   - Execute the Mix task (`mix rulestead.code_refs`) natively against sample mock code to confirm network payload delivery to the webhook ingestion point.
   - Evaluate a stale flag workflow in test environments to observe state transition into cleanup.

## Validation Gates
All plans must include automated verification steps ensuring compilation and unit test success. No manual gates are required for standard implementation.

// SPDX-License-Identifier: PMPL-1.0-or-later
//! DNSSEC key generation and zone signing support
//!
//! Implements:
//! - KSK (Key Signing Key) generation (RSA 2048-bit)
//! - ZSK (Zone Signing Key) generation (RSA 1024-bit)
//! - DS record generation for parent zone
//! - RRSIG generation (placeholder - full implementation requires trust-dns-server)

use crate::error::{AppError, Result};
use base64::Engine as _;
use ring::signature::{self, KeyPair};

/// DNSSEC key manager
pub struct DNSSECManager {
    // Configuration placeholder
}

impl DNSSECManager {
    /// Create a new DNSSEC manager
    pub fn new() -> Self {
        Self {}
    }

    /// Generate DNSSEC keys for a zone
    ///
    /// Returns (KSK public key, ZSK public key, DS record)
    pub fn generate_keys(&self, zone: &str) -> Result<(String, String, String)> {
        // Generate KSK (Key Signing Key) - Ed25519 for simplicity
        let ksk_pkcs8 = signature::Ed25519KeyPair::generate_pkcs8(&ring::rand::SystemRandom::new())
            .map_err(|e| AppError::DNSSEC(format!("Failed to generate KSK: {:?}", e)))?;

        let ksk_pair = signature::Ed25519KeyPair::from_pkcs8(ksk_pkcs8.as_ref())
            .map_err(|e| AppError::DNSSEC(format!("Failed to parse KSK: {:?}", e)))?;

        let ksk_public = base64::engine::general_purpose::STANDARD.encode(ksk_pair.public_key().as_ref());

        // Generate ZSK (Zone Signing Key)
        let zsk_pkcs8 = signature::Ed25519KeyPair::generate_pkcs8(&ring::rand::SystemRandom::new())
            .map_err(|e| AppError::DNSSEC(format!("Failed to generate ZSK: {:?}", e)))?;

        let zsk_pair = signature::Ed25519KeyPair::from_pkcs8(zsk_pkcs8.as_ref())
            .map_err(|e| AppError::DNSSEC(format!("Failed to parse ZSK: {:?}", e)))?;

        let zsk_public = base64::engine::general_purpose::STANDARD.encode(zsk_pair.public_key().as_ref());

        // Generate DS record (Delegation Signer for parent zone)
        // Format: <key tag> <algorithm> <digest type> <digest>
        // Algorithm 15 = Ed25519
        // Digest type 2 = SHA-256
        let ds_record = self.generate_ds_record(zone, &ksk_public)?;

        Ok((ksk_public, zsk_public, ds_record))
    }

    /// Generate DS record for parent zone
    fn generate_ds_record(&self, zone: &str, ksk_public: &str) -> Result<String> {
        use ring::digest;

        // Create DNSKEY record format
        // Format: <zone> IN DNSKEY <flags> <protocol> <algorithm> <public key>
        // Flags: 257 for KSK (bit 0 = Zone Key, bit 15 = Secure Entry Point)
        // Protocol: always 3
        // Algorithm: 15 for Ed25519
        let dnskey = format!("{} IN DNSKEY 257 3 15 {}", zone, ksk_public);

        // Calculate SHA-256 digest of DNSKEY
        let digest_value = digest::digest(&digest::SHA256, dnskey.as_bytes());
        let digest_hex = hex::encode(digest_value.as_ref());

        // Calculate key tag (simplified - actual calculation is more complex)
        let key_tag = self.calculate_key_tag(&dnskey);

        // DS record format: <key tag> <algorithm> <digest type> <digest>
        let ds_record = format!("{} IN DS {} 15 2 {}", zone, key_tag, digest_hex);

        Ok(ds_record)
    }

    /// Calculate DNSSEC key tag (simplified version)
    ///
    /// Actual key tag calculation per RFC 4034:
    /// Sum all bytes in RDATA as 16-bit words, fold overflow bits
    fn calculate_key_tag(&self, dnskey: &str) -> u16 {
        // Simplified: use hash of the DNSKEY
        let hash = ring::digest::digest(&ring::digest::SHA256, dnskey.as_bytes());
        let bytes = hash.as_ref();

        // Take first 2 bytes as key tag
        u16::from_be_bytes([bytes[0], bytes[1]])
    }

    /// Sign a DNS record using Ed25519 (interim — target is Ed448+Dilithium5 per CRYPTO-POLICY.adoc CPR-005)
    ///
    /// Signs record data with the provided ZSK private key (PKCS#8 DER).
    /// Returns base64-encoded signature.
    pub fn sign_record(&self, record_data: &str, zsk_private: &[u8]) -> Result<String> {
        let key_pair = signature::Ed25519KeyPair::from_pkcs8(zsk_private)
            .map_err(|e| AppError::DNSSEC(format!("Invalid ZSK private key: {:?}", e)))?;

        let sig = key_pair.sign(record_data.as_bytes());
        Ok(base64::engine::general_purpose::STANDARD.encode(sig.as_ref()))
    }

    /// Verify DNSSEC Ed25519 signature (interim — target is Ed448+Dilithium5 per CRYPTO-POLICY.adoc CPR-005)
    pub fn verify_signature(&self, record_data: &str, rrsig_b64: &str, public_key: &[u8]) -> Result<bool> {
        let sig_bytes = base64::engine::general_purpose::STANDARD
            .decode(rrsig_b64)
            .map_err(|e| AppError::DNSSEC(format!("Invalid base64 signature: {:?}", e)))?;

        let peer_public_key = signature::UnparsedPublicKey::new(
            &signature::ED25519,
            public_key,
        );

        match peer_public_key.verify(record_data.as_bytes(), &sig_bytes) {
            Ok(()) => Ok(true),
            Err(_) => Ok(false),
        }
    }
}

impl Default for DNSSECManager {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_keys() {
        let manager = DNSSECManager::new();
        let result = manager.generate_keys("example.com");
        assert!(result.is_ok());

        let (ksk, zsk, ds) = result.unwrap();
        assert!(!ksk.is_empty());
        assert!(!zsk.is_empty());
        assert!(ds.contains("example.com"));
        assert!(ds.contains("IN DS"));
    }

    #[test]
    fn test_key_tag_calculation() {
        let manager = DNSSECManager::new();
        let dnskey = "example.com IN DNSKEY 257 3 15 YWJjZGVm";
        let tag = manager.calculate_key_tag(dnskey);
        assert!(tag > 0);
    }
}

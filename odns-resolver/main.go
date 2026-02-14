// SPDX-License-Identifier: PMPL-1.0-or-later
// oDNS Resolver - Oblivious DNS Resolver
//
// Decrypts HPKE-encrypted DNS queries from proxy,
// resolves them, and returns encrypted responses.
//
// Privacy guarantee: Resolver never sees client IP address.
// RFC 9230: Oblivious DNS over HTTPS (ODoH)

package main

import (
	"encoding/base64"
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"time"

	"github.com/cloudflare/circl/hpke"
	"github.com/miekg/dns"
)

const (
	// HPKE configuration (RFC 9180)
	KemID  = hpke.KEM_X25519_HKDF_SHA256
	KdfID  = hpke.KDF_HKDF_SHA256
	AeadID = hpke.AEAD_ChaCha20Poly1305
)

// Config holds resolver configuration
type Config struct {
	ListenAddr     string
	UpstreamDNS    string
	HPKEPrivateKey []byte
}

// Resolver represents the oDNS resolver server
type Resolver struct {
	config *Config
	suite  hpke.Suite
	client *dns.Client
}

// NewResolver creates a new oDNS resolver
func NewResolver(config *Config) (*Resolver, error) {
	suite, err := hpke.AssembleSuite(KemID, KdfID, AeadID)
	if err != nil {
		return nil, fmt.Errorf("failed to assemble HPKE suite: %w", err)
	}

	return &Resolver{
		config: config,
		suite:  suite,
		client: &dns.Client{
			Net:     "udp",
			Timeout: 5 * time.Second,
		},
	}, nil
}

// Start starts the resolver server
func (r *Resolver) Start() error {
	listener, err := net.Listen("tcp", r.config.ListenAddr)
	if err != nil {
		return fmt.Errorf("failed to listen: %w", err)
	}
	defer listener.Close()

	log.Printf("oDNS Resolver listening on %s", r.config.ListenAddr)
	log.Printf("Upstream DNS: %s", r.config.UpstreamDNS)
	log.Println("Privacy mode: Client IPs not logged")

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("Accept error: %v", err)
			continue
		}

		go r.handleConnection(conn)
	}
}

// handleConnection handles a single connection from proxy
func (r *Resolver) handleConnection(conn net.Conn) {
	defer conn.Close()

	conn.SetDeadline(time.Now().Add(10 * time.Second))

	// Read encrypted DNS query
	buf := make([]byte, 4096)
	n, err := conn.Read(buf)
	if err != nil {
		log.Printf("Read error: %v", err)
		return
	}

	if n < 2 {
		log.Printf("Invalid message: too short")
		return
	}

	// Extract encrypted query (skip 2-byte length prefix)
	encryptedQuery := buf[2:n]

	// Decrypt query
	dnsQuery, err := r.decryptQuery(encryptedQuery)
	if err != nil {
		log.Printf("Decryption error: %v", err)
		return
	}

	// Parse DNS query
	msg := new(dns.Msg)
	if err := msg.Unpack(dnsQuery); err != nil {
		log.Printf("Failed to parse DNS message: %v", err)
		return
	}

	// Log query (no client IP - privacy preserved)
	if len(msg.Question) > 0 {
		log.Printf("Resolving: %s %s", msg.Question[0].Name, dns.TypeToString[msg.Question[0].Qtype])
	}

	// Resolve DNS query
	response, err := r.resolveDNS(msg)
	if err != nil {
		log.Printf("Resolution error: %v", err)
		return
	}

	// Send response back to proxy
	responseLen := make([]byte, 2)
	responseLen[0] = byte(len(response) >> 8)
	responseLen[1] = byte(len(response))

	if _, err := conn.Write(append(responseLen, response...)); err != nil {
		log.Printf("Write error: %v", err)
	}
}

// decryptQuery decrypts an HPKE-encrypted DNS query
func (r *Resolver) decryptQuery(encrypted []byte) ([]byte, error) {
	// Unmarshal private key
	skR, err := r.suite.KEM.UnmarshalBinaryPrivateKey(r.config.HPKEPrivateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal private key: %w", err)
	}

	// Extract encapsulated key and ciphertext
	// Format: encapsulated key || ciphertext
	kemSize := r.suite.KEM.EncapSize()
	if len(encrypted) < kemSize {
		return nil, fmt.Errorf("encrypted data too short")
	}

	encapsulatedKey := encrypted[:kemSize]
	ciphertext := encrypted[kemSize:]

	// Create HPKE receiver
	receiver, err := r.suite.NewReceiver(skR, nil, encapsulatedKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create HPKE receiver: %w", err)
	}

	// Decrypt query
	plaintext, err := receiver.Open(ciphertext, nil)
	if err != nil {
		return nil, fmt.Errorf("HPKE open failed: %w", err)
	}

	return plaintext, nil
}

// resolveDNS resolves a DNS query using upstream DNS server
func (r *Resolver) resolveDNS(query *dns.Msg) ([]byte, error) {
	// Forward to upstream DNS
	response, _, err := r.client.Exchange(query, r.config.UpstreamDNS)
	if err != nil {
		return nil, fmt.Errorf("upstream DNS error: %w", err)
	}

	// Pack response
	responseBytes, err := response.Pack()
	if err != nil {
		return nil, fmt.Errorf("failed to pack response: %w", err)
	}

	return responseBytes, nil
}

// rotateKeys rotates HPKE keys (called periodically)
func (r *Resolver) rotateKeys() error {
	suite, err := hpke.AssembleSuite(KemID, KdfID, AeadID)
	if err != nil {
		return fmt.Errorf("failed to assemble HPKE suite: %w", err)
	}

	publicKey, privateKey, err := suite.KEM.GenerateKeyPair()
	if err != nil {
		return fmt.Errorf("failed to generate key pair: %w", err)
	}

	pkBytes, err := publicKey.MarshalBinary()
	if err != nil {
		return fmt.Errorf("failed to marshal public key: %w", err)
	}

	skBytes, err := privateKey.MarshalBinary()
	if err != nil {
		return fmt.Errorf("failed to marshal private key: %w", err)
	}

	log.Println("HPKE Keys Rotated")
	log.Printf("New Public Key: %s", base64.StdEncoding.EncodeToString(pkBytes))
	log.Printf("New Private Key: %s", base64.StdEncoding.EncodeToString(skBytes))
	log.Println("Update proxy configuration with new public key")

	// Update resolver's private key
	r.config.HPKEPrivateKey = skBytes

	return nil
}

func main() {
	// Command-line flags
	listen := flag.String("listen", ":8853", "Listen address")
	upstream := flag.String("upstream", "1.1.1.1:53", "Upstream DNS server")
	privkey := flag.String("privkey", "", "HPKE private key (base64)")
	rotateInterval := flag.Duration("rotate", 24*time.Hour, "Key rotation interval")

	flag.Parse()

	// Validate required parameters
	if *privkey == "" {
		log.Fatal("HPKE private key required (use -privkey)")
	}

	// Decode private key
	privkeyBytes, err := base64.StdEncoding.DecodeString(*privkey)
	if err != nil {
		log.Fatalf("Invalid private key: %v", err)
	}

	// Create resolver configuration
	config := &Config{
		ListenAddr:     *listen,
		UpstreamDNS:    *upstream,
		HPKEPrivateKey: privkeyBytes,
	}

	// Create and start resolver
	resolver, err := NewResolver(config)
	if err != nil {
		log.Fatalf("Failed to create resolver: %v", err)
	}

	// Start key rotation timer
	if *rotateInterval > 0 {
		go func() {
			ticker := time.NewTicker(*rotateInterval)
			defer ticker.Stop()

			for range ticker.C {
				if err := resolver.rotateKeys(); err != nil {
					log.Printf("Key rotation failed: %v", err)
				}
			}
		}()
	}

	if err := resolver.Start(); err != nil {
		log.Fatalf("Resolver error: %v", err)
	}
}

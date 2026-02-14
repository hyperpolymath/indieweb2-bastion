// SPDX-License-Identifier: PMPL-1.0-or-later
// oDNS Proxy - Oblivious DNS Proxy
//
// Encrypts DNS queries with HPKE before forwarding to resolver,
// ensuring resolver cannot see client IP address.
//
// RFC 9230: Oblivious DNS over HTTPS (ODoH)
// Adapted for DNS over TLS (DoT)

package main

import (
	"crypto/tls"
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

// Config holds proxy configuration
type Config struct {
	ListenAddr    string
	ResolverAddr  string
	HPKEPublicKey []byte
	TLSCert       string
	TLSKey        string
	IPv6Only      bool
}

// Proxy represents the oDNS proxy server
type Proxy struct {
	config *Config
	suite  hpke.Suite
}

// NewProxy creates a new oDNS proxy
func NewProxy(config *Config) (*Proxy, error) {
	suite, err := hpke.AssembleSuite(KemID, KdfID, AeadID)
	if err != nil {
		return nil, fmt.Errorf("failed to assemble HPKE suite: %w", err)
	}

	return &Proxy{
		config: config,
		suite:  suite,
	}, nil
}

// Start starts the proxy server
func (p *Proxy) Start() error {
	// Load TLS certificate
	cert, err := tls.LoadX509KeyPair(p.config.TLSCert, p.config.TLSKey)
	if err != nil {
		return fmt.Errorf("failed to load TLS certificate: %w", err)
	}

	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS13, // TLS 1.3 only
	}

	// Listen on DNS over TLS (DoT) port 853
	listener, err := tls.Listen("tcp", p.config.ListenAddr, tlsConfig)
	if err != nil {
		return fmt.Errorf("failed to listen: %w", err)
	}
	defer listener.Close()

	log.Printf("oDNS Proxy listening on %s (DoT)", p.config.ListenAddr)
	log.Printf("Forwarding to resolver: %s", p.config.ResolverAddr)
	log.Printf("IPv6-only mode: %v", p.config.IPv6Only)

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Printf("Accept error: %v", err)
			continue
		}

		go p.handleConnection(conn)
	}
}

// handleConnection handles a single DoT connection
func (p *Proxy) handleConnection(conn net.Conn) {
	defer conn.Close()

	// Set connection deadline
	conn.SetDeadline(time.Now().Add(10 * time.Second))

	// Read DNS query (TCP format: 2-byte length + DNS message)
	buf := make([]byte, 512)
	n, err := conn.Read(buf)
	if err != nil {
		log.Printf("Read error: %v", err)
		return
	}

	if n < 2 {
		log.Printf("Invalid DNS message: too short")
		return
	}

	// Extract DNS message (skip 2-byte length prefix)
	dnsMsg := buf[2:n]

	// Parse DNS query
	msg := new(dns.Msg)
	if err := msg.Unpack(dnsMsg); err != nil {
		log.Printf("Failed to parse DNS message: %v", err)
		return
	}

	// Log query (privacy-preserving: no client IP)
	if len(msg.Question) > 0 {
		log.Printf("Query: %s %s", msg.Question[0].Name, dns.TypeToString[msg.Question[0].Qtype])
	}

	// Encrypt query with HPKE
	encryptedQuery, err := p.encryptQuery(dnsMsg)
	if err != nil {
		log.Printf("Encryption error: %v", err)
		return
	}

	// Forward to resolver
	response, err := p.forwardToResolver(encryptedQuery)
	if err != nil {
		log.Printf("Forward error: %v", err)
		return
	}

	// Send response back to client
	responseLen := make([]byte, 2)
	responseLen[0] = byte(len(response) >> 8)
	responseLen[1] = byte(len(response))

	if _, err := conn.Write(append(responseLen, response...)); err != nil {
		log.Printf("Write error: %v", err)
	}
}

// encryptQuery encrypts a DNS query using HPKE
func (p *Proxy) encryptQuery(query []byte) ([]byte, error) {
	// Unmarshal public key
	pkR, err := p.suite.KEM.UnmarshalBinaryPublicKey(p.config.HPKEPublicKey)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal public key: %w", err)
	}

	// Create HPKE sender
	sender, err := p.suite.NewSender(pkR, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create HPKE sender: %w", err)
	}

	// Encrypt query
	// Format: encapsulated key || ciphertext
	encapsulatedKey, ciphertext, err := sender.Seal(query, nil)
	if err != nil {
		return nil, fmt.Errorf("HPKE seal failed: %w", err)
	}

	// Concatenate encapsulated key and ciphertext
	encrypted := append(encapsulatedKey, ciphertext...)

	return encrypted, nil
}

// forwardToResolver forwards encrypted query to oDNS resolver
func (p *Proxy) forwardToResolver(encryptedQuery []byte) ([]byte, error) {
	// Connect to resolver
	conn, err := net.DialTimeout("tcp", p.config.ResolverAddr, 5*time.Second)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to resolver: %w", err)
	}
	defer conn.Close()

	conn.SetDeadline(time.Now().Add(10 * time.Second))

	// Send encrypted query (TCP format: 2-byte length + payload)
	queryLen := make([]byte, 2)
	queryLen[0] = byte(len(encryptedQuery) >> 8)
	queryLen[1] = byte(len(encryptedQuery))

	if _, err := conn.Write(append(queryLen, encryptedQuery...)); err != nil {
		return nil, fmt.Errorf("failed to send to resolver: %w", err)
	}

	// Read response
	buf := make([]byte, 4096)
	n, err := conn.Read(buf)
	if err != nil {
		return nil, fmt.Errorf("failed to read from resolver: %w", err)
	}

	if n < 2 {
		return nil, fmt.Errorf("invalid response: too short")
	}

	// Extract response (skip 2-byte length prefix)
	response := buf[2:n]

	return response, nil
}

// generateHPKEKeys generates a new HPKE key pair
func generateHPKEKeys() error {
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

	fmt.Println("HPKE Key Pair Generated (X25519)")
	fmt.Println("================================")
	fmt.Printf("Public Key (base64):  %s\n", base64.StdEncoding.EncodeToString(pkBytes))
	fmt.Printf("Private Key (base64): %s\n", base64.StdEncoding.EncodeToString(skBytes))
	fmt.Println("\nStore the private key securely on the resolver.")
	fmt.Println("Configure the proxy with the public key.")

	return nil
}

func main() {
	// Command-line flags
	listen := flag.String("listen", ":853", "Listen address (DoT port 853)")
	resolver := flag.String("resolver", "localhost:8853", "Resolver address")
	pubkey := flag.String("pubkey", "", "HPKE public key (base64)")
	tlsCert := flag.String("cert", "cert.pem", "TLS certificate file")
	tlsKey := flag.String("key", "key.pem", "TLS private key file")
	ipv6Only := flag.Bool("ipv6-only", false, "IPv6-only mode")
	genKeys := flag.Bool("genkeys", false, "Generate HPKE key pair and exit")

	flag.Parse()

	// Generate keys if requested
	if *genKeys {
		if err := generateHPKEKeys(); err != nil {
			log.Fatalf("Key generation failed: %v", err)
		}
		return
	}

	// Validate required parameters
	if *pubkey == "" {
		log.Fatal("HPKE public key required (use -pubkey or -genkeys)")
	}

	// Decode public key
	pubkeyBytes, err := base64.StdEncoding.DecodeString(*pubkey)
	if err != nil {
		log.Fatalf("Invalid public key: %v", err)
	}

	// Check TLS certificate exists
	if _, err := os.Stat(*tlsCert); os.IsNotExist(err) {
		log.Fatalf("TLS certificate not found: %s", *tlsCert)
	}
	if _, err := os.Stat(*tlsKey); os.IsNotExist(err) {
		log.Fatalf("TLS private key not found: %s", *tlsKey)
	}

	// Create proxy configuration
	config := &Config{
		ListenAddr:    *listen,
		ResolverAddr:  *resolver,
		HPKEPublicKey: pubkeyBytes,
		TLSCert:       *tlsCert,
		TLSKey:        *tlsKey,
		IPv6Only:      *ipv6Only,
	}

	// Create and start proxy
	proxy, err := NewProxy(config)
	if err != nil {
		log.Fatalf("Failed to create proxy: %v", err)
	}

	if err := proxy.Start(); err != nil {
		log.Fatalf("Proxy error: %v", err)
	}
}

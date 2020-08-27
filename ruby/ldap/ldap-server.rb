# https://tools.ietf.org/html/rfc4511
https://tools.ietf.org/html/rfc4517
require 'socket'
require 'openssl'
# require_relative 'oid.rb'

module LDAP
  MESSAGE_OP = {
    bindRequest: 0,
    bindResponse: 1,
    unbindRequest: 2,
    searchRequest: 3,
    searchResEntry: 4,
    searchResDone: 5,
    searchResRef: 19,
    modifyRequest: 6,
    modifyResponse: 7,
    addRequest: 8,
    addResponse: 9,
    delRequest: 10,
    delResponse: 11,
    modDNRequest: 12,
    modDNResponse: 13,
    compareRequest: 14,
    compareResponse: 15,
    abandonRequest: 16,
    extendedReq: 23,
    extendedResp: 24,
    intermediateResponse: 25,
  }
  SEARCH_SCOPE ={
    baseObject: 0,
    singleLevel: 1,
    wholeSubtree: 2,
  }
  SEARCH_DEREF_ALIASES ={
    neverDerefAliases: 0,
    derefInSearching: 1,
    derefFindingBaseObj: 2,
    derefAlways: 3
  }
  RESULT_CODE = {
    success: 0,
    operationsError: 1,
    protocolError: 2,
    timeLimitExceeded: 3,
    sizeLimitExceeded: 4,
    compareFalse: 5,
    compareTrue: 6,
    authMethodNotSupported: 7,
    strongerAuthRequired: 8,
  # 9 reserved
    referral: 10,
    adminLimitExceeded: 11,
    unavailableCriticalExtension: 12,
    confidentialityRequired: 13,
    saslBindInProgress: 14,
    noSuchAttribute: 16,
    undefinedAttributeType: 17,
    inappropriateMatching: 18,
    constraintViolation: 19,
    attributeOrValueExists: 20,
    invalidAttributeSyntax: 21,
  # 22-31 unused
    noSuchObject: 32,
    aliasProblem: 33,
    invalidDNSyntax: 34,
  # 35 reserved for undefined isLeaf
    aliasDereferencingProblem: 36,
  # 37-47 unused
    inappropriateAuthentication: 48,
    invalidCredentials: 49,
    insufficientAccessRights: 50,
    busy: 51,
    unavailable: 52,
    unwillingToPerform: 53,
    loopDetect: 54,
  # 55-63 unused
    namingViolation: 64,
    objectClassViolation: 65,
    notAllowedOnNonLeaf: 66,
    notAllowedOnRDN: 67,
    entryAlreadyExists: 68,
    objectClassModsProhibited: 69,
  # 70 reserved for CLDAP
    affectsMultipleDSAs: 71,
  # 72-79 unused
    other: 80,
  }
end
# https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml
SASL_MECHANISMS = %w(
  9798-M-DSA-SHA1 9798-M-ECDSA-SHA1 9798-M-RSA-SHA1-ENC
  9798-U-DSA-SHA1 9798-U-ECDSA-SHA1 9798-U-RSA-SHA1-ENC
  ANONYMOUS CRAM-MD5 DIGEST-MD5 EAP-AES128 EAP-AES128-PLUS EXTERNAL
  GS2-KRB5 GS2-KRB5-PLUS GSS-SPNEGO GSSAPI KERBEROS_V4 KERBEROS_V5
  LOGIN NMAS_AUTHEN NMAS_LOGIN NMAS-SAMBA-AUTH NTLM
  OAUTH10A OAUTHBEARER OPENID20
  OTP PLAIN SAML20 SECURID SKEY SPNEGO SPNEGO-PLUS
  XOAUTH XOAUTH2 SCRAM-SHA-1 SCRAM-SHA-1-PLUS SCRAM-SHA-256 SCRAM-SHA-256-PLUS
)


class LDAPMessage
  attr :id, :contents
  def initialize(asn1string)
    message = OpenSSL::ASN1.decode(asn1string) unless asn1string.respond_to?(:to_der)
    @id = message.value[0].value.to_i
    raise "AH" if @id <= 0
    type = LDAP::MESSAGE_OP.key(message.value[1].tag)
    case type
    when :bindRequest
      @contents = {
        type: :auth,
        bind_dn: message.value[1].value[1].value,
      }
      when message.value[1].value[2].tag
      case 0
        @contents[:auth_type] = :simple,
        @contents[:password] = message.value[1].value[2].value
      case 3
        t = message.value[1].value[2].value
        @contents[:auth_type] = :sasl,
        @contents[:sasl_method] = t.first.value,
        @contents[:password] = t[1].value rescue nil # optional
      else
        raise "not supported"
      end
    when :searchRequest
      t = message.value[1].value
      @contents = {
        type: :search,
        baseObject: t.first.value,
        scope: LDAP::SEARCH_SCOPE.key(t[1].value),
        derefAliases: LDAP::SEARCH_DEREF_ALIASES.key(t[2].value),
        sizeLimit: t[3].value.to_int, #Integer(t[3].value, 10),
        timeLimit: t[4].value.to_int, #Integer(t[4].value, 10),
        typesOnly: t[5].value,
        filter: t[6].value,
        attributes: t[7].value.map(&:value)
      }
    when :unbindRequest
      @contents = {type: type}
    else
      raise "Not supported yet"
    end
  end

  def self.compose(id, op, seq)
    (OpenSSL::ASN1::Sequence([
      OpenSSL::ASN1::Integer(id),
      OpenSSL::ASN1::Sequence(seq, LDAP::MESSAGE_OP[op], :IMPLICIT, :APPLICATION),
    ])).to_der
  end
  def self.compose_sucess(id, op)
    LDAPMessage.compose(id, op,
      [OpenSSL::ASN1::Enumerated(LDAP::RESULT_CODE[:success]), OpenSSL::ASN1::OctetString(""), OpenSSL::ASN1::OctetString("")]
    )
  end
  def self.compose_search_entries(id, dn='', **kv)
    LDAPMessage.compose(id, :searchResEntry,[
      OpenSSL::ASN1::OctetString(dn),
      OpenSSL::ASN1::Sequence(kv.map{|k,v| OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::OctetString(k.to_s),
        OpenSSL::ASN1::Set([*v].map{|e| OpenSSL::ASN1::OctetString(e)})])})
    ])
  end
end

#server = TCPServer.new 389
server = TCPServer.new 1234
loop do
  client = server.accept
  Thread.new do
    while true
      message = p LDAPMessage.new(client.readpartial(30000))
      case message.contents[:type]
      when :auth
        client.print(LDAPMessage.compose_sucess(message.id, :bindResponse))
        puts "Simple auth response sent"
      when :search
        if message.contents.values_at(:baseObject, :scope, :derefAliases, :sizeLimit, :timeLimit, :typesOnly, :filter, :attributes) == ['',:baseObject,:neverDerefAliases,0,0,false,"objectclass",["supportedSASLMechanisms"]]
          client.print(LDAPMessage.compose_search_entries(message.id, supportedSASLMechanisms: SASL_MECHANISMS))
          puts "returned all known SASL-mechanisms"
        else
          client.print(LDAPMessage.compose_search_entries(message.id, telephoneNumber: ["asdf", "+1 512 315 0280"]))
          client.print(LDAPMessage.compose_search_entries(message.id, "dnhere", keystuff: "valuestuff"))
          puts "Stupid search response(s) sent"
        end
        client.print(LDAPMessage.compose_sucess(message.id, :searchResDone))
      when :unbindRequest
        client.close
        puts "connection closed, bye"
        break
      else
        raise "AHHHHHHHHHH Don't know what to do!"
      end
    end
  end
end



public enum OTAPConnectionError: Error {
    case missingMessageContext,
         messageNotComplete,
         missingPacketHeader,
         cannotCreateMessage
}

public enum OTAPPacketError: Error {
    case exceededMTUSize,
         expectedMoreData,
         malformedPayload,
         cannotCreatePacket
}

public enum OTAPClientError: Error {
    case notConnected,
         notAuthenticated,
         unsupportedProtocolVersion,
         unexpectedServerResponse,
         updateFrequencyNotAllowed,
         serverError(NetworkError)
}

public enum NetworkError: UInt8, Error {
    case general,
         notAuthorized = 6,
         notExpected,
         wrongRevision,
         nameInUse,
         wrongPassword,
         companyMismatch,
         kicked,
         cheater,
         full,
         tooManyCommands,
         timeoutPassword,
         timeoutComputer,
         timeoutMap,
         timeoutJoin,
         invalidClientName,
         notOnAllowList
}

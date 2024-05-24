
public enum OTAPError: Error {

    case exceededMTUSize,
         expectedMoreData,
         malformedPayload,
         unknownPacketType,
         invalidPacketType,
         missingPacketHeader,
         unexpectedPayloadLength,
         missingMessageContext,
         messageNotComplete,
         cannotCreateMessage
}

//MARK: -

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

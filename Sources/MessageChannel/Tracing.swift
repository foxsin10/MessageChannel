import Foundation

protocol Traceable {
    func replay()
    func record<M: Message>(message: M, from channel: MessageDispatchChannel)
}


struct Tracing: Traceable {
    func replay() {

    }

    func record<M>(
        message: M,
        from channel: MessageDispatchChannel
    ) where M : Message {

    }
}

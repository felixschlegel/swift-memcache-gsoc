//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memcache-gsoc open source project
//
// Copyright (c) 2023 Apple Inc. and the swift-memcache-gsoc project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of swift-memcache-gsoc project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOPosix
@testable import SwiftMemcache
import XCTest

final class MemcachedIntegrationTest: XCTestCase {
    var channel: ClientBootstrap!
    var group: EventLoopGroup!

    override func setUp() {
        super.setUp()
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.channel = ClientBootstrap(group: self.group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(MessageToByteHandler(MemcachedRequestEncoder()))
            }
    }

    override func tearDown() {
        XCTAssertNoThrow(try self.group.syncShutdownGracefully())
        super.tearDown()
    }

    func testConnectionToMemcachedServer() throws {
        do {
            let connection = try channel.connect(host: "memcached", port: 11211).wait()
            XCTAssertNotNil(connection)

            // Prepare a MemcachedRequest
            var buffer = ByteBufferAllocator().buffer(capacity: 3)
            buffer.writeString("hi")
            let command = MemcachedRequest.SetCommand(key: "foo", value: buffer)
            let request = MemcachedRequest.set(command)

            // Write the request to the connection and wait for the result
            connection.writeAndFlush(request).whenComplete { result in
                switch result {
                case .success:
                    print("Request successfully sent to the server.")
                case .failure(let error):
                    XCTFail("Failed to send request: \(error)")
                }
            }
        } catch {
            XCTFail("Failed to connect to Memcached server: \(error)")
        }
    }
}
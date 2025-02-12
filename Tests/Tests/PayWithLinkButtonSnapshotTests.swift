//
//  PayWithLinkButtonSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable import Stripe

class PayWithLinkButtonSnapshotTests: FBSnapshotTestCase {

    private let emailAddress = "customer@example.com"
    private let longEmailAddress = "long.customer.name@example.com"

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testDefault() {
        let sut = makeSUT()
        sut.linkAccount = makeAccountStub(email: emailAddress, isRegistered: false)
        verify(sut)

        sut.isHighlighted = true
        verify(sut, identifier: "Highlighted")
    }

    func testDefault_rounded() {
        let sut = makeSUT()
        sut.cornerRadius = 16
        sut.linkAccount = makeAccountStub(email: emailAddress, isRegistered: false)
        verify(sut)
    }

    func testDisabled() {
        let sut = makeSUT()
        sut.isEnabled = false
        verify(sut)
    }

    func testRegistered() {
        let sut = makeSUT()
        sut.linkAccount = makeAccountStub(email: emailAddress, isRegistered: true)
        verify(sut)
    }

    func testRegistered_rounded() {
        let sut = makeSUT()
        sut.cornerRadius = 16
        sut.linkAccount = makeAccountStub(email: emailAddress, isRegistered: true)
        verify(sut)
    }

    func testRegistered_square() {
        let sut = makeSUT()
        sut.cornerRadius = 0
        sut.linkAccount = makeAccountStub(email: emailAddress, isRegistered: true)
        verify(sut)
    }

    func testRegistered_withLongEmailAddress() {
        let sut = PayWithLinkButton()
        sut.linkAccount = makeAccountStub(email: longEmailAddress, isRegistered: true)
        verify(sut)
    }

    func verify(
        _ sut: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.autosizeHeight(width: 300)
        STPSnapshotVerifyView(sut, identifier: identifier, file: file, line: line)
    }

}

private extension PayWithLinkButtonSnapshotTests {

    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let isLoggedIn: Bool
    }

    func makeAccountStub(email: String, isRegistered: Bool) -> LinkAccountStub {
        return LinkAccountStub(
            email: email,
            redactedPhoneNumber: "+1********55",
            isRegistered: isRegistered,
            isLoggedIn: false
        )
    }

    func makeSUT() -> PayWithLinkButton {
        return PayWithLinkButton()
    }

}

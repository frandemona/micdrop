import Testing
@testable import MicDrop

@Suite struct FeedbackMailerTests {
    @Test func buildsMailtoWithRecipientAndVersionedSubject() {
        let url = FeedbackMailer.mailtoURL(version: "1.2.3")
        #expect(url.absoluteString == "mailto:francisco@zereb.ro?subject=MicDrop%20Feedback%20(v1.2.3)")
    }
}

require "spec_helper"

describe Gemstash::WebHelper do
  before(:all) do
    @server = SimpleServer.new("localhost")
    @other_server = SimpleServer.new("127.0.0.1")
    @server.mount_message("/simple_fetch", "Simple fetch results")
    @server.mount_message("/error", "Error result", 500)
    @server.mount_message("/missing", "Missing value", 404)
    @server.mount_redirect("/redirect", "/simple_fetch")
    @server.mount_redirect("/other_redirect", "#{@other_server.url}/redirect")
    @other_server.mount_redirect("/redirect", "#{@server.url}/simple_fetch")
    @server.start
    @other_server.start
  end

  after(:all) do
    @server.stop
    @other_server.stop
  end

  describe ".get" do
    let(:helper) { Gemstash::WebHelper.new(server_url: @server.url) }

    context "with a valid url" do
      it "returns the body of the result" do
        expect(helper.get("/simple_fetch")).to eq("Simple fetch results")
      end
    end

    context "with a valid redirect" do
      it "returns the body of the result after the redirect" do
        expect(helper.get("/redirect")).to eq("Simple fetch results")
      end
    end

    context "with a redirect to a different server" do
      it "returns the body of the result after the redirects" do
        expect(helper.get("/other_redirect")).to eq("Simple fetch results")
      end
    end

    context "with a url that returns a 500" do
      it "throws an error" do
        expect { helper.get("/error") }.to raise_error do |error|
          expect(error).to be_a(Gemstash::WebError)
          expect(error.message).to eq("Error result")
          expect(error.code).to eq(500)
        end
      end
    end

    context "with a url that returns a 404" do
      it "throws an error" do
        expect { helper.get("/missing") }.to raise_error do |error|
          expect(error).to be_a(Gemstash::WebError)
          expect(error.message).to eq("Missing value")
          expect(error.code).to eq(404)
        end
      end
    end

    context "with a block to store the headers" do
      let(:http_client) do
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get("/gems/rack") { [200, { "CONTENT-TYPE" => "octet/stream" }, "zapatito"] }
        end
        Faraday.new {|builder| builder.adapter(:test, stubs) }
      end

      let(:helper) { Gemstash::WebHelper.new(http_client: http_client) }

      it "throws an error" do
        body_result = nil
        headers_result = nil

        helper.get("/gems/rack") do |body, headers|
          body_result = body
          headers_result = headers
        end

        expect(body_result).to eq("zapatito")
        expect(headers_result).to eq("CONTENT-TYPE" => "octet/stream")
      end
    end
  end
end

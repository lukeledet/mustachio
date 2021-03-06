require 'spec_helper'
require 'rack/test'

describe Mustachio::App do
  include Rack::Test::Methods

  def app
    subject
  end

  describe "GET /" do
    it "shows the homepage" do
      get '/'
      expect(last_response.status).to eq(200)
      expect(last_response.body).to include('Created by')
    end
  end

  describe "GET /?src=..." do
    it "handles a Rekognition API failure" do
      stub_request(:get, 'http://example.com/dubya.jpeg').to_return(body: image_file('dubya.jpeg'))
      expect(Mustachio::Rekognition).to receive(:face_detection).and_raise(Mustachio::Rekognition::Error)
      get '/?src=http://example.com/dubya.jpeg'
      expect(last_response.status).to eq(502)
    end

    it "handles a missing image file" do
      stub_request(:get, 'http://existentsite.com/missing.png').to_return(status: 404)
      get '/?src=http://existentsite.com/missing.png'
      expect(last_response.status).to eq(502)
    end

    it "handles a missing image host" do
      stub_request(:get, 'http://nonexistentsite.com/foo.png').to_raise(SocketError)
      get '/?src=http://nonexistentsite.com/foo.png'
      expect(last_response.status).to eq(502)
    end

    it "handles when the image format can't be processed" do
      stub_request(:get, 'http://example.com/handbag.webp').to_return(body: image_file('handbag.webp'))
      get '/?src=http://example.com/handbag.webp'
      expect(last_response.status).to eq(415)
    end

    it "handles when the image download times out" do
      stub_request(:get, 'http://slowsite.com/foo.png').to_timeout
      get '/?src=http://slowsite.com/foo.png'
      expect(last_response.status).to eq(504)
    end

    it "handles invalid URLs" do
      get '/?src=foo'
      expect(last_response.status).to eq(415)
    end
  end
end

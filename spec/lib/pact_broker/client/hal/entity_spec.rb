require 'pact_broker/client/hal/entity'
require 'pact_broker/client/hal/http_client'

module PactBroker::Client
  module Hal
    describe Entity do
      let(:http_client) do
        instance_double('Pact::Hal::HttpClient', post: provider_response)
      end

      let(:provider_response) do
        double('response', body_hash: provider_hash, success?: true)
      end

      let(:provider_hash) do
        {
          "name" => "Provider"
        }
      end
      let(:pact_hash) do
        {
          "name" => "a name",

          "_links" => {
            "pb:provider" => {
              "href" => "http://provider"
            },
            "pb:version-tag" => {
              "href" => "http://provider/version/{version}/tag/{tag}"
            }
          }
        }
      end

      subject(:entity) { Entity.new(pact_hash, http_client) }

      it "delegates to the properties in the data" do
        expect(subject.name).to eq "a name"
      end

      describe "post" do
        let(:post_provider) { entity.post("pb:provider", {'some' => 'data'} ) }

        it "executes an http request" do
          expect(http_client).to receive(:post).with("http://provider", '{"some":"data"}', {})
          post_provider
        end

        it "returns the entity for the relation" do
          expect(post_provider).to be_a(Entity)
        end

        context "with template params" do
          let(:post_provider) { entity._link("pb:version-tag").expand(version: "1", tag: "prod").post({'some' => 'data'} ) }

          it "posts to the expanded URL" do
            expect(http_client).to receive(:post).with("http://provider/version/1/tag/prod", '{"some":"data"}', {})
            post_provider
          end
        end
      end

      describe "can?" do
        context "when the relation exists" do
          it "returns true" do
            expect(subject.can?('pb:provider')).to be true
          end
        end

        context "when the relation does not exist" do
          it "returns false" do
            expect(subject.can?('pb:consumer')).to be false
          end
        end
      end

      describe 'fetch' do
        context 'when the key exist' do
          it 'returns fetched value' do
            expect(subject.fetch('pb:provider')).to be do
              {href: 'http://provider'}
            end
          end
        end
        context "when the key doesn't not exist" do
          it 'returns nil' do
            expect(subject.fetch('i-dont-exist')).to be nil
          end
        end
      end
    end
  end
end
